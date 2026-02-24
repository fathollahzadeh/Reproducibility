WITH PostTagCount AS (
    SELECT
        p.Id AS PostId,
        COUNT(*) AS TagCount
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1
    GROUP BY
        p.Id
),
UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked
    FROM
        Users u
    JOIN
        Posts p ON u.Id = p.OwnerUserId
    WHERE
        p.PostTypeId = 1
    GROUP BY
        u.Id, u.Reputation, u.DisplayName
),
ReputationBracket AS (
    SELECT
        CASE
            WHEN Reputation >= 1000 THEN 'High Reputation'
            WHEN Reputation >= 100 THEN 'Medium Reputation'
            ELSE 'Low Reputation'
        END AS ReputationCategory,
        COUNT(*) AS UserCount
    FROM
        UserReputation
    GROUP BY
        CASE
            WHEN Reputation >= 1000 THEN 'High Reputation'
            WHEN Reputation >= 100 THEN 'Medium Reputation'
            ELSE 'Low Reputation'
        END
),
CloseReasonAnalysis AS (
    SELECT
        chr.Id AS CloseReasonId,
        chr.Name AS CloseReason,
        COUNT(ph.Id) AS PostClosedCount
    FROM
        CloseReasonTypes chr
    JOIN
        PostHistory ph ON chr.Id = CAST(ph.Comment AS int)
    WHERE
        ph.PostHistoryTypeId = 10
    GROUP BY
        chr.Id, chr.Name
),
TagAnalysis AS (
    SELECT
        t.TagName,
        COUNT(DISTINCT pl.PostId) AS LinkedPostCount
    FROM
        Tags t
    JOIN
        PostLinks pl ON pl.RelatedPostId = t.WikiPostId
    GROUP BY
        t.TagName
)
SELECT
    r.ReputationCategory,
    r.UserCount,
    c.CloseReason,
    c.PostClosedCount,
    t.TagName,
    t.LinkedPostCount,
    ptc.TagCount
FROM
    ReputationBracket r
LEFT JOIN
    CloseReasonAnalysis c ON 1=1  
LEFT JOIN
    TagAnalysis t ON 1=1          
LEFT JOIN
    PostTagCount ptc ON ptc.PostId = 1  
ORDER BY
    r.ReputationCategory,
    c.PostClosedCount DESC,
    t.LinkedPostCount DESC;