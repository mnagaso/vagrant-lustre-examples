import nodemailer from "nodemailer";

interface EmailOptions {
  to: string;
  subject: string;
  text: string;
  html?: string;
}

export async function sendEmail(options: EmailOptions): Promise<void> {
  const gmailUser = process.env.EMAIL_USER;
  const gmailAppPassword = process.env.EMAIL_PASSWORD;

  if (!gmailUser || !gmailAppPassword) {
    throw new Error("Email credentials not provided. Please set GMAIL_USER and GMAIL_APP_PASSWORD in your environment.");
  }

  const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: gmailUser,
      pass: gmailAppPassword
    }
  });

  const mailOptions = {
    from: gmailUser,
    to: options.to,
    subject: options.subject,
    text: options.text,
    html: options.html || options.text
  };

  await transporter.sendMail(mailOptions);
}
