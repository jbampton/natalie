#include "natalie/enumerator/arithmetic_sequence_object.hpp"
#include "natalie.hpp"

namespace Natalie::Enumerator {
Integer ArithmeticSequenceObject::calculate_step_count(Env *env) {
    auto n = m_end->send(env, "-"_s, { m_begin })->send(env, "/"_s, { step() });

    Integer step_count;
    if (n->is_integer()) {
        step_count = n->as_integer()->integer();
    } else {
        step_count = n->send(env, "+"_s, { n->send(env, "*"_s, { new FloatObject { std::numeric_limits<double>::epsilon() } }) })->send(env, "floor"_s)->as_integer()->integer();
    }

    if (!exclude_end())
        step_count += 1;

    return step_count;
}

bool ArithmeticSequenceObject::eq(Env *env, Value other) {
    if (!other->is_enumerator_arithmetic_sequence())
        return false;

    ArithmeticSequenceObject *other_sequence = other->as_enumerator_arithmetic_sequence();
    return hash(env)->equal(other_sequence->hash(env));
}

Value ArithmeticSequenceObject::hash(Env *env) {
    HashBuilder hash_builder {};
    auto hash_method = "hash"_s;

    auto add = [&hash_builder, &hash_method, env](Value value) {
        auto hash = value->send(env, hash_method);

        if (hash->is_nil())
            return;

        auto nat_int = IntegerObject::convert_to_nat_int_t(env, hash);
        hash_builder.append(nat_int);
    };

    add(m_begin);
    add(m_end);
    add(step());

    if (m_exclude_end)
        add(TrueObject::the());
    else
        add(FalseObject::the());

    return IntegerObject::create(hash_builder.digest());
}

Value ArithmeticSequenceObject::inspect(Env *env) {
    switch (m_origin) {
    case Origin::Range: {
        auto range_inspect = RangeObject(m_begin, m_end, m_exclude_end).inspect_str(env);
        auto string = StringObject::format("(({}).step", range_inspect);

        if (has_step()) {
            string->append_char('(');
            string->append(m_step);
            string->append_char(')');
        }

        string->append_char(')');

        return string;
    }
    case Origin::Numeric: {
        auto string = StringObject::format("({}.step({}", m_begin, m_end);

        if (has_step()) {
            string->append(", ");
            string->append(m_step);
        }

        string->append("))");

        return string;
    }
    }
    return nullptr;
}

Value ArithmeticSequenceObject::last(Env *env) {
    if (m_exclude_end) {
        auto steps = step_count(env);
        return m_begin->send(env, "+"_s, { IntegerObject::create(steps)->send(env, "*"_s, { step() }) });
    } else {
        return m_end;
    }
}

Value ArithmeticSequenceObject::size(Env *env) {
    if (m_end->send(env, "infinite?"_s)->is_truthy())
        return FloatObject::positive_infinity(env);

    return IntegerObject::create(step_count(env));
}
};
