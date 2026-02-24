WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes, 
        COUNT(DISTINCT p.Id) AS TotalPosts,
        AVG(COALESCE(NULLIF(p.Score, 0), NULL)) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
RankedUsers AS (
    SELECT 
        UserId,
        UpVotes,
        DownVotes,
        TotalPosts,
        AvgScore,
        RANK() OVER (ORDER BY AvgScore DESC, UpVotes DESC) AS ScoreRank
    FROM 
        UserVoteSummary
),
TopBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
)
SELECT 
    u.DisplayName,
    COALESCE(b.BadgeCount, 0) AS GoldBadgeCount,
    r.UpVotes,
    r.DownVotes,
    r.TotalPosts,
    r.AvgScore,
    r.ScoreRank
FROM 
    Users u
LEFT JOIN 
    RankedUsers r ON u.Id = r.UserId
LEFT JOIN 
    TopBadges b ON u.Id = b.UserId
WHERE 
    (r.ScoreRank <= 10 OR r.UpVotes >= 100) 
    AND u.Reputation > 500
ORDER BY 
    r.ScoreRank, u.DisplayName;