export default function Spinner() {
  return (
    <div className="flex items-center justify-center min-h-[40vh]">
      <div className="w-8 h-8 rounded-full border-2 border-[var(--border)] border-t-[var(--brand)] animate-spin" />
    </div>
  );
}
