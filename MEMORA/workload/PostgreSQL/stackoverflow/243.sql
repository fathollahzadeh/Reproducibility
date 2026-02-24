WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViews
    FROM 
        Users u 
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    GROUP BY 
        u.Id, u.DisplayName
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS VoteCount,
        MAX(v.CreationDate) AS LastVoteDate
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
EnhancedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        us.UserId,
        us.DisplayName,
        us.QuestionCount,
        us.TotalScore,
        us.AvgViews,
        rv.VoteCount,
        rv.LastVoteDate
    FROM 
        RankedPosts rp
    INNER JOIN 
        UserStats us ON rp.PostId IN (
            SELECT p.Id FROM Posts p WHERE p.OwnerUserId = us.UserId
        )
    LEFT JOIN 
        RecentVotes rv ON rp.PostId = rv.PostId
    WHERE 
        rp.PostRank <= 5
)
SELECT 
    ep.Title,
    ep.CreationDate,
    ep.Score,
    ep.ViewCount,
    ep.VoteCount,
    ep.LastVoteDate,
    CONCAT('User: ', ep.DisplayName, ' | Questions: ', ep.QuestionCount, ' | Total Score: ', ep.TotalScore, ' | Avg Views: ', COALESCE(ep.AvgViews, 0)) AS UserStats
FROM 
    EnhancedPosts ep
WHERE 
    ep.TotalScore IS NOT NULL AND ep.ViewCount > 100
ORDER BY 
    ep.Score DESC, ep.VoteCount DESC;
