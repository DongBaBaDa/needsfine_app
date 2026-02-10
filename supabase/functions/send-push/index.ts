import { createClient } from "npm:@supabase/supabase-js@2"
import { JWT } from "npm:google-auth-library@9"

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const firebaseServiceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT')!)

const supabase = createClient(supabaseUrl, supabaseServiceKey)

const getAccessToken = () => {
    return new Promise((resolve, reject) => {
        const jwtClient = new JWT(
            firebaseServiceAccount.client_email,
            null,
            firebaseServiceAccount.private_key,
            ['https://www.googleapis.com/auth/cloud-platform'],
            null
        )
        jwtClient.authorize((err, tokens) => {
            if (err) {
                reject(err)
                return
            }
            resolve(tokens.access_token)
        })
    })
}

Deno.serve(async (req) => {
    try {
        const { record } = await req.json()
        const { receiver_id, title, content } = record

        // 1. 해당 유저의 FCM 토큰 조회
        const { data: tokens, error: tokenError } = await supabase
            .from('fcm_tokens')
            .select('token')
            .eq('user_id', receiver_id)

        if (tokenError || !tokens || tokens.length === 0) {
            return new Response(JSON.stringify({ message: 'No tokens found' }), { status: 200 })
        }

        // 2. FCM 액세스 토큰 획득
        const accessToken = await getAccessToken()

        // 3. 각 토큰으로 푸시 발송
        const projectId = firebaseServiceAccount.project_id
        const results = await Promise.all(tokens.map(async ({ token }) => {
            const res = await fetch(
                `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
                {
                    method: 'POST',
                    headers: {
                        'Authorization': `Bearer ${accessToken}`,
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        message: {
                            token: token,
                            notification: {
                                title: title,
                                body: content,
                            },
                        },
                    }),
                }
            )
            return res.json()
        }))

        return new Response(JSON.stringify({ results }), { status: 200 })
    } catch (err) {
        return new Response(JSON.stringify({ error: err.message }), { status: 500 })
    }
})
