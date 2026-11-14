/* ============================================================
   YEP System — Global JavaScript
   Plain vanilla JS (no frameworks).
   ============================================================ */

/* Auto-dismiss success messages after 6 seconds */
document.addEventListener('DOMContentLoaded', function () {

    // Dismiss success/info messages automatically; errors stay until the user acts
    document.querySelectorAll('.flash-wrap .alert-success, .flash-wrap .alert-info').forEach(function (alert) {
        setTimeout(function () {
            alert.style.transition = 'opacity 0.5s';
            alert.style.opacity = '0';
            setTimeout(function () { alert.remove(); }, 500);
        }, 6000);
    });

    // Confirm before destructive form actions
    document.querySelectorAll('[data-confirm]').forEach(function (el) {
        el.addEventListener('click', function (e) {
            if (!confirm(el.getAttribute('data-confirm'))) {
                e.preventDefault();
            }
        });
    });

    // Client-side password strength indicator on the registration form
    var passwordInput = document.getElementById('password');
    var strengthBar   = document.getElementById('strengthBar');
    if (passwordInput && strengthBar) {
        passwordInput.addEventListener('input', function () {
            var val = passwordInput.value;
            var strength = 0;
            if (val.length >= 8) strength++;
            if (/[A-Za-z]/.test(val)) strength++;
            if (/[0-9]/.test(val)) strength++;
            if (/[^A-Za-z0-9]/.test(val)) strength++;

            var colours = ['#e74c3c', '#e67e22', '#f1c40f', '#27ae60'];
            var labels  = ['Too short', 'Weak', 'Fair', 'Strong'];

            strengthBar.style.width = (strength * 25) + '%';
            strengthBar.style.background = colours[strength - 1] || '#ccc';
            var label = document.getElementById('strengthLabel');
            if (label) label.textContent = labels[strength - 1] || '';
        });
    }

});
