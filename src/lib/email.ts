import { Resend } from 'resend';

const RESEND_API_KEY = process.env.RESEND_API_KEY!;
const EMAIL_FROM = process.env.EMAIL_FROM!;

const resend = new Resend(RESEND_API_KEY);

/**
 * Minimal HTML mailer. Extend with templates as needed.
 */
export async function sendEmail(to: string, subject: string, html: string) {
  if (!RESEND_API_KEY) throw new Error('RESEND_API_KEY not set');
  if (!EMAIL_FROM) throw new Error('EMAIL_FROM not set');
  const { data, error } = await resend.emails.send({
    from: EMAIL_FROM,
    to,
    subject,
    html,
  });
  if (error) throw error;
  return data;
}
