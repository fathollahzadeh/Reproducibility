WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year'
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        SUM(CASE 
            WHEN v.VoteTypeId = 2 THEN 1 
            WHEN v.VoteTypeId = 3 THEN -1 
            ELSE 0 
        END) AS UserVoteScore
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        us.UserVoteScore
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Posts re ON rp.PostId = re.AcceptedAnswerId
    LEFT JOIN 
        UserScores us ON re.OwnerUserId = us.UserId
    WHERE 
        rp.Rank <= 10
),
AggregatePosts AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(ViewCount) AS AvgViewCount,
        SUM(Score) AS TotalScore,
        SUM(UserVoteScore) AS TotalUserVoteScore
    FROM 
        PostDetails
)

SELECT 
    p.Title,
    COALESCE(p.ViewCount, 0) AS ViewCount,
    COALESCE(p.Score, 0) AS Score,
    ap.TotalPosts,
    ap.AvgViewCount,
    ap.TotalScore,
    ap.TotalUserVoteScore
FROM 
    PostDetails p
CROSS JOIN 
    AggregatePosts ap
WHERE 
    p.ViewCount > ap.AvgViewCount
ORDER BY 
    p.Score DESC, p.ViewCount DESC;