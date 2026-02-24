
WITH ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PopularQuestions AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score
    ORDER BY 
        VoteCount DESC, p.ViewCount DESC
    LIMIT 10
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment,
        pt.Name AS PostType
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    ORDER BY 
        ph.CreationDate DESC
)
SELECT 
    au.UserId,
    au.DisplayName,
    au.Reputation,
    au.PostCount,
    au.CommentCount,
    au.GoldBadges,
    au.SilverBadges,
    au.BronzeBadges,
    pq.Title AS PopularQuestion,
    pq.ViewCount AS QuestionViewCount,
    pq.Score AS QuestionScore,
    re.CreationDate AS RecentEditDate,
    re.UserDisplayName AS EditorName,
    re.Comment AS EditComment,
    re.PostType
FROM 
    ActiveUsers au
LEFT JOIN 
    PopularQuestions pq ON au.PostCount > 5 
LEFT JOIN 
    RecentEdits re ON re.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = au.UserId)
ORDER BY 
    au.Reputation DESC, 
    pq.ViewCount DESC, 
    re.CreationDate DESC;
