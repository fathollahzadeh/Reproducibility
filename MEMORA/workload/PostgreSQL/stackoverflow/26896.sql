
WITH TagAggregation AS (
    SELECT 
        SPLIT_PART(tag.TNAME, '>', 1) AS MainTag,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(u.Reputation) AS AvgUserReputation,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS ActiveUsers
    FROM 
        Posts p
    JOIN 
        (SELECT DISTINCT 
            UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><')) AS TNAME 
        FROM 
            Posts) AS tag ON p.Tags LIKE '%' || tag.TNAME || '%'
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATE '2023-10-01'
    GROUP BY 
        MainTag
), 
TopBadges AS (
    SELECT 
        b.Name AS BadgeName,
        COUNT(DISTINCT b.UserId) AS RecipientCount
    FROM 
        Badges b
    GROUP BY 
        b.Name
    ORDER BY 
        RecipientCount DESC
    LIMIT 5
)

SELECT 
    ta.MainTag,
    ta.PostCount,
    ta.AvgUserReputation,
    ta.ActiveUsers,
    tb.BadgeName,
    tb.RecipientCount
FROM 
    TagAggregation ta
LEFT JOIN 
    TopBadges tb ON ta.AvgUserReputation >= (
        SELECT 
            AVG(u.Reputation)
        FROM 
            Users u
        WHERE 
            u.Reputation IS NOT NULL
            AND u.Reputation < ta.AvgUserReputation
    )
ORDER BY 
    ta.PostCount DESC, 
    tb.RecipientCount DESC;
