declare variable $retain-singletons := false();

declare function local:osisBook($nodeId)
{
    switch (xs:integer(substring($nodeId, 1, 2)))
        case 40
            return
                "Matt"
        case 41
            return
                "Mark"
        case 42
            return
                "Luke"
        case 43
            return
                "John"
        case 44
            return
                "Acts"
        case 45
            return
                "Rom"
        case 46
            return
                "1Cor"
        case 47
            return
                "2Cor"
        case 48
            return
                "Gal"
        case 49
            return
                "Eph"
        case 50
            return
                "Phil"
        case 51
            return
                "Col"
        case 52
            return
                "1Thess"
        case 53
            return
                "2Thess"
        case 54
            return
                "1Tim"
        case 55
            return
                "2Tim"
        case 56
            return
                "Titus"
        case 57
            return
                "Phlm"
        case 58
            return
                "Heb"
        case 59
            return
                "Jas"
        case 60
            return
                "1Pet"
        case 61
            return
                "2Pet"
        case 62
            return
                "1John"
        case 63
            return
                "2John"
        case 64
            return
                "3John"
        case 65
            return
                "Jude"
        case 66
            return
                "Rev"
        default return
            "###"
};

declare function local:verbal-noun-type($node)
{
    switch ($node/parent::Node/@Cat)
        case 'adjp'
            return
                attribute type {'adjectival'}
        case 'advp'
            return
                attribute type {'adverbial'}
        case 'np'
            return
                attribute type {'nominal'}
        default return
           attribute type {'###'}
};

declare function local:attributes($node)
{
    $node/@Cat ! attribute class {lower-case(.)},
    $node/@Type ! attribute type {lower-case(.)}[string-length(.) >= 1 and not(. = ("Logical", "Negative"))],
    $node/@morphId ! attribute osisId {local:osisId(.)},
    $node/@HasDet ! attribute articular {true()},
    $node/@UnicodeLemma ! attribute lemma {.},
    $node/@NormalizedForm ! attribute normalized {.},
    $node/@StrongNumber ! attribute strong {.},
    $node/@Number ! attribute number {lower-case(.)},
    $node/@Person ! attribute person {lower-case(.)},
    $node/@Gender ! attribute gender {lower-case(.)},
    $node/@Case ! attribute case {lower-case(.)},
    $node/@Tense ! attribute tense {lower-case(.)},
    $node/@Voice ! attribute voice {lower-case(.)},
    $node/@Mood ! attribute mood {lower-case(.)},
    $node/@Mood[. = ('Participle', 'Infinitive')] ! local:verbal-noun-type($node),
    $node/@Degree ! attribute degree {lower-case(.)},
    $node/parent::*/@Head ! attribute head {"true"}[$node/parent::*/@Head = count($node/preceding-sibling::*)],
    $node[empty(*)] ! attribute discontinuous {"true"}[$node/following::Node[empty(*)][1]/@morphId lt $node/@morphId],
    $node/@HasDet ! attribute det {"true"}
};

declare function local:osisId($nodeId)
{
    concat(local:osisBook($nodeId),
    ".",
    xs:integer(substring($nodeId, 3, 3)),
    ".",
    xs:integer(substring($nodeId, 6, 3)),
    "!",
    xs:integer(substring($nodeId, 9, 3))
    )
};

declare function local:clause($node)
{
    <wg>
        {
            local:attributes($node),
            $node/Node ! local:node(.)
        }
    </wg>
};

declare function local:phrase($node)
{
    <wg>
        {
            local:attributes($node),
            $node/Node ! local:node(.)
        }
    </wg>
};

declare function local:role($node)
(:
  A role node can have more than one child in some
  corner cases in the GBI trees, e.g. Gal 4:18, where
  an ADV node contains ADV conj ADV.  I imagine this
  occurs only for conjunctions, but I am not sure.
:)
{
    let $role := attribute role {lower-case($node/@Cat)}
    return
        if (count($node/Node) > 1)
        then
            <wg>
                {
                    $role, $node/Node ! local:node(.)
                }
            </wg>
        else
            let $target := ($node/Node)
            return
                if (local:node-type($target) = "word")
                then
                    local:word($target, $role)
                else
                    <wg>
                        {
                            $role,
                            local:attributes($target),
                            $target/Node ! local:node(.)
                        }
                    </wg>
};

declare function local:milestones($node)
{
    let $nodeId := $node/@nodeId
    let $parentId := $node/parent::Node/@nodeId
    let $chapter := substring($nodeId, 3, 3)
    let $verse := substring($nodeId, 6, 3)
    let $word := substring($nodeId, 9, 3)
    let $osisId := local:osisId($nodeId)
    where substring($nodeId, 1, 11) != substring($parentId, 1, 11)
    return
        if ($verse = "001" and $word = "001")
        then
            (
            <milestone
                unit="chapter"
                n="{substring-before($osisId, ".1!")}"/>,
            <milestone
                unit="verse"
                n="{substring-before($osisId, "!")}"/>
            )
        else
            if ($word = "001")
            then
                <milestone
                    unit="verse"
                    n="{substring-before($osisId, "!")}"/>
            else
                ()
};

declare function local:word($node)
{
    local:word($node, ())
};

declare function local:word($node, $role)
(: $role can contain a role attribute or a null sequence :)
{
    if (string-length($node) = string-length($node/@NormalizedForm) + 1)
    then
        (: place punctuation in a separate node :)
        (
        <w>
            {
                $role,
                local:attributes($node),
                substring($node, 1, string-length($node) - 1)
            }
        </w>,
        <pu>{substring($node, string-length($node), 1)}</pu>
        )
    else
        <w>
            {
                $role,
                local:attributes($node),
                string($node)
            }
        </w>
};

declare function local:node-type($node as element(Node))
{
    switch ($node/@Cat)
        case "adj"
        case "adv"
        case "conj"
        case "det"
        case "intj"
        case "noun"
        case "num"
        case "prep"
        case "ptcl"
        case "pron"
        case "verb"
            return
                "word"
        case "adjp"
        case "advp"
        case "np"
        case "nump"
        case "pp"
        case "vp"
            return
                "phrase"
        case "S"
        case "IO"
        case "ADV"
        case "O"
        case "O2"
        case "P"
        case "V"
        case "VC"
            return
                "role"
        case "CL"
            return
                "clause"
        default
        return
            <cat>{$node/@Cat}</cat>
};

declare function local:node($node as element(Node))
{
    local:milestones($node),
    switch (local:node-type($node))
        case "word"
            return
                local:word($node)
        case "phrase"
            return
                local:phrase($node)
        case "role"
            return
                local:role($node)
        case "clause"
            return
                local:clause($node)
        default
        return
            <cat>{$node/@Cat}</cat>
};

declare function local:sentence($node)
{
    local:milestones($node),
    <wg
        class="sentence">
        {
            $node/Node ! local:node(.)
        }
    </wg>
};

<div
    class="book">
    {
        for $sentence in //Tree/Node
        return
            local:sentence($sentence)
    }
</wg>
