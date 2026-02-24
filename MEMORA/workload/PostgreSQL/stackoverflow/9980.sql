
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(AVG(v.BountyAmount) FILTER (WHERE v.VoteTypeId IN (8, 9)), 0) AS AverageBounty,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseActions,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        PostHistory ph ON ph.PostId = p.Id
    LEFT JOIN 
        LATERAL UNNEST(string_to_array(p.Tags, ',')) AS tag_name ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = TRIM(tag_name)
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.AnswerCount
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts
    FROM 
        Users u
    JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
CombinedStats AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.ViewCount,
        ps.Score,
        ps.AnswerCount,
        ps.CommentCount,
        ps.AverageBounty,
        ps.CloseActions,
        ps.Tags,
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ur.PostCount,
        ur.PositivePosts
    FROM 
        PostStats ps
    JOIN 
        UserReputation ur ON ur.UserId = (
            SELECT 
                OwnerUserId 
            FROM 
                Posts 
            WHERE 
                Id = ps.PostId
        )
)
SELECT 
    *,
    (SELECT COUNT(*) FROM PostHistory WHERE PostId IN (SELECT PostId FROM PostStats)) AS TotalPostHistoryActions
FROM 
    CombinedStats
ORDER BY 
    ViewCount DESC
FETCH FIRST 100 ROWS ONLY;
