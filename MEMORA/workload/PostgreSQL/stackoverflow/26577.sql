
WITH TagData AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.Tags,
        ARRAY_AGG(DISTINCT t.TagName) AS TagNames,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT bh.Id) AS HistoryCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory bh ON p.Id = bh.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        LATERAL UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><')) AS tag ON tag IS NOT NULL
    LEFT JOIN 
        Tags t ON tag = t.TagName
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.Tags
),
UserData AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        CASE 
            WHEN COUNT(b.Id) > 0 THEN 'Has Badges'
            ELSE 'No Badges'
        END AS BadgeStatus,
        SUM(CASE WHEN p.AnswerCount > 0 THEN 1 ELSE 0 END) AS QuestionsWithAnswers
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    t.PostId,
    t.Title,
    t.TagNames,
    t.CommentCount,
    t.HistoryCount,
    t.UpVotes,
    u.DisplayName,
    u.Reputation,
    u.BadgeStatus,
    u.QuestionsWithAnswers
FROM 
    TagData t
JOIN 
    UserData u ON t.OwnerUserId = u.UserId
ORDER BY 
    t.UpVotes DESC, 
    t.CommentCount DESC, 
    u.Reputation DESC
FETCH FIRST 100 ROWS ONLY;
