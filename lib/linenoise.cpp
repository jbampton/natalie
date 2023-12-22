#include "../lib/linenoise.hpp"
#include "natalie.hpp"

using namespace Natalie;

Value Linenoise_add_history(Env *env, Value self, Args args, Block *) {
    args.ensure_argc_is(env, 1);
    auto line = args[0]->as_string_or_raise(env)->string();

    linenoise::AddHistory(line.c_str());

    return args[0];
}

Value Linenoise_clear_screen(Env *env, Value self, Args args, Block *) {
    args.ensure_argc_is(env, 0);
    linenoise::linenoiseClearScreen();
    return NilObject::the();
}

Value Linenoise_get_history(Env *env, Value self, Args args, Block *) {
    args.ensure_argc_is(env, 0);

    auto history = linenoise::GetHistory();

    auto ary = new ArrayObject {};
    for (auto item : history)
        ary->push(new StringObject { item.c_str() });

    return ary;
}

Value Linenoise_get_multi_line(Env *env, Value self, Args args, Block *) {
    args.ensure_argc_is(env, 0);
    return bool_object(linenoise::GetMultiLine());
}

Value Linenoise_load_history(Env *env, Value self, Args args, Block *) {
    args.ensure_argc_is(env, 1);
    auto path = args[0]->as_string_or_raise(env)->string();

    linenoise::LoadHistory(path.c_str());

    return NilObject::the();
}

Value Linenoise_readline(Env *env, Value self, Args args, Block *) {
    args.ensure_argc_is(env, 1);

    auto prompt = args[0]->as_string_or_raise(env)->string();

    std::string line;
    auto quit = linenoise::Readline(prompt.c_str(), line);

    if (quit)
        return NilObject::the();

    return new StringObject { line.c_str(), line.size() };
}

Value Linenoise_save_history(Env *env, Value self, Args args, Block *) {
    args.ensure_argc_is(env, 1);
    auto path = args[0]->as_string_or_raise(env)->string();

    linenoise::SaveHistory(path.c_str());

    return NilObject::the();
}

Value Linenoise_set_completion_callback(Env *env, Value self, Args args, Block *) {
    args.ensure_argc_is(env, 1);
    args[0]->assert_type(env, Object::Type::Proc, "Proc");
    auto proc = args[0]->as_proc();

    // Ensure the GC doesn't try to claim this object.
    self->ivar_set(env, "@completion_callback"_s, proc);

    linenoise::SetCompletionCallback([proc](const char *edit_buffer, std::vector<std::string> &completions) {
        auto edit_buffer_string = new StringObject { edit_buffer };
        auto env = proc->env();
        auto ary = proc->send(env, "call"_s, { edit_buffer_string })->as_array_or_raise(env);
        for (auto &completion : *ary) {
            completions.push_back(completion->as_string()->c_str());
        }
    });

    return NilObject::the();
}

Value Linenoise_set_history(Env *env, Value self, Args args, Block *) {
    args.ensure_argc_is(env, 1);
    auto ary = args[0]->as_array_or_raise(env);

    auto &history = linenoise::GetHistory();
    history.clear();

    for (auto item : *ary)
        history.push_back(item->as_string_or_raise(env)->c_str());

    return ary;
}

Value Linenoise_set_history_max_len(Env *env, Value self, Args args, Block *) {
    args.ensure_argc_is(env, 1);
    auto length = args[0]->as_integer_or_raise(env)->to_nat_int_t();
    linenoise::SetHistoryMaxLen(length);
    return Value::integer(length);
}

Value Linenoise_set_multi_line(Env *env, Value self, Args args, Block *) {
    args.ensure_argc_is(env, 1);
    auto enabled = args[0]->is_truthy();
    linenoise::SetMultiLine(enabled);
    return bool_object(enabled);
}

Value init(Env *env, Value self) {
    auto Linenoise = new ModuleObject { "Linenoise" };
    GlobalEnv::the()->Object()->const_set("Linenoise"_s, Linenoise);

    Linenoise->define_singleton_method(env, "add_history"_s, Linenoise_add_history, 1);
    Linenoise->define_singleton_method(env, "clear_screen"_s, Linenoise_clear_screen, 0);
    Linenoise->define_singleton_method(env, "completion_callback="_s, Linenoise_set_completion_callback, 1);
    Linenoise->define_singleton_method(env, "history"_s, Linenoise_get_history, 0);
    Linenoise->define_singleton_method(env, "history="_s, Linenoise_set_history, 1);
    Linenoise->define_singleton_method(env, "history_max_len="_s, Linenoise_set_history_max_len, 1);
    Linenoise->define_singleton_method(env, "load_history"_s, Linenoise_load_history, 1);
    Linenoise->define_singleton_method(env, "multi_line"_s, Linenoise_get_multi_line, 0);
    Linenoise->define_singleton_method(env, "multi_line="_s, Linenoise_set_multi_line, 1);
    Linenoise->define_singleton_method(env, "readline"_s, Linenoise_readline, 1);
    Linenoise->define_singleton_method(env, "save_history"_s, Linenoise_save_history, 1);

    return NilObject::the();
}