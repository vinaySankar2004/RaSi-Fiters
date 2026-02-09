"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/lib/auth/auth-provider";
import { BackButton } from "@/components/BackButton";
import { useActiveProgram } from "@/lib/use-active-program";

export default function PrivacyPolicyPage() {
  const router = useRouter();
  const { session, isBootstrapping } = useAuth();
  const program = useActiveProgram();
  const fallbackHref = program?.id ? "/program" : "/programs";

  useEffect(() => {
    if (!isBootstrapping && !session?.token) {
      router.push("/login");
    }
  }, [isBootstrapping, session?.token, router]);

  return (
    <div className="min-h-screen px-6 pb-16 pt-10 text-rf-text sm:px-10">
      <div className="mx-auto w-full max-w-3xl space-y-6">
        <header className="space-y-2">
          <BackButton fallbackHref={fallbackHref} />
          <h1 className="text-2xl font-bold">Privacy Policy</h1>
          <p className="text-sm text-rf-text-muted">Effective date: 2026-02-02</p>
        </header>

        <div className="glass-card rounded-3xl p-6 space-y-6 text-sm text-rf-text-muted">
          <p>
            RaSi Fiters ("we", "us", or "our") respects your privacy. This policy explains what
            information we collect, how we use it, and the choices you have. This policy applies
            to the RaSi Fiters mobile app and related services.
          </p>

          <div>
            <p className="text-base font-semibold text-rf-text">Information we collect</p>
            <ul className="mt-2 list-disc space-y-1 pl-5">
              <li>Account information: name, email address, and password (stored securely).</li>
              <li>Profile information: optional gender field.</li>
              <li>Fitness and activity data: workout, sleep and diet quality which you log in the app.</li>
              <li>Usage data: app interactions, feature usage, and diagnostic logs.</li>
              <li>Device and network data: device type, OS version, and IP address.</li>
            </ul>
          </div>

          <div>
            <p className="text-base font-semibold text-rf-text">How we use information</p>
            <ul className="mt-2 list-disc space-y-1 pl-5">
              <li>Provide and operate the app, including authentication and core features.</li>
              <li>Personalize and improve the app experience.</li>
              <li>Monitor performance, fix bugs, and maintain security.</li>
              <li>Communicate with you about your account or support requests.</li>
            </ul>
          </div>

          <div>
            <p className="text-base font-semibold text-rf-text">Sharing of information</p>
            <ul className="mt-2 list-disc space-y-1 pl-5">
              <li>
                Service providers: we may share data with vendors who help us operate the app
                (for example, hosting and analytics). They are required to protect your information.
              </li>
              <li>
                Legal requirements: we may disclose information if required by law or to protect
                our rights and users.
              </li>
            </ul>
            <p className="mt-2">We do not sell your personal information.</p>
          </div>

          <div>
            <p className="text-base font-semibold text-rf-text">Data retention</p>
            <p className="mt-2">
              We keep information only as long as needed to provide the service and comply with legal
              obligations. You can request deletion at any time.
            </p>
          </div>

          <div>
            <p className="text-base font-semibold text-rf-text">Security</p>
            <p className="mt-2">
              We use reasonable safeguards to protect your data, but no method of transmission or
              storage is 100% secure.
            </p>
          </div>

          <div>
            <p className="text-base font-semibold text-rf-text">Your choices</p>
            <ul className="mt-2 list-disc space-y-1 pl-5">
              <li>Access or update your information in the app.</li>
              <li>Request deletion by contacting us.</li>
            </ul>
          </div>

          <div>
            <p className="text-base font-semibold text-rf-text">Children's privacy</p>
            <p className="mt-2">RaSi Fiters is not intended for children under 4.</p>
          </div>

          <div>
            <p className="text-base font-semibold text-rf-text">Changes to this policy</p>
            <p className="mt-2">
              We may update this policy from time to time. If we make changes, we will update the
              effective date above.
            </p>
          </div>

          <div>
            <p className="text-base font-semibold text-rf-text">Contact us</p>
            <p className="mt-2">If you have questions or requests, contact us at:</p>
            <p className="mt-1 font-semibold text-rf-text">geethasankar78@gmail.com</p>
          </div>
        </div>
      </div>
    </div>
  );
}
