class Validators {
    static String? emailValidator(String value) {
        var pattern =
                r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
        RegExp regex = new RegExp(pattern);

        return !regex.hasMatch(value) ? 'E-mail must be valid' : null;
    }

    static String? passwordValidator(String value) {
        final result = value.length < 8
                ? 'Password length should be more then 8 characters'
                : null;

        return result;
    }

    static String? passwordsMatchValidator(String oldValue, String newValue) {
        if (oldValue.length < 8 || newValue.length < 8) return null;

        final result = oldValue != newValue ? 'Passwords does not match' : null;

        return result;
    }
}