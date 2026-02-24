WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScores
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
HighScorers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.PostCount,
        us.TotalViews,
        us.PositiveScores,
        RANK() OVER (ORDER BY us.Reputation DESC, us.PostCount DESC) AS Rank
    FROM 
        UserStats us
    WHERE 
        us.Reputation > 1000 
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS TagUsageCount
    FROM 
        Tags t
    JOIN 
        Posts p ON POSITION(t.TagName IN p.Tags) > 0
    GROUP BY 
        t.TagName
    ORDER BY 
        TagUsageCount DESC
    LIMIT 10
)
SELECT 
    ps.DisplayName,
    ps.Reputation,
    ps.PostCount,
    ps.TotalViews,
    ps.PositiveScores,
    tp.TagName,
    tp.TagUsageCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.UserId = ps.UserId AND v.VoteTypeId IN (2, 3)) AS TotalVotes
FROM 
    HighScorers ps
CROSS JOIN 
    TopTags tp
WHERE 
    ps.Rank <= 50
AND 
    EXISTS (
        SELECT 1
        FROM RankedPosts rp
        WHERE rp.PostId IN (
            SELECT p.Id
            FROM Posts p
            WHERE p.OwnerUserId = ps.UserId
              AND p.Score IS NOT NULL
            LIMIT 1
        )
        AND rp.PostRank <= 3
    )
ORDER BY 
    ps.Reputation DESC, 
    tp.TagUsageCount DESC;