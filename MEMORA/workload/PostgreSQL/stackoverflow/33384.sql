WITH RecursivePostCount AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(Score) AS TotalScore,
        RANK() OVER (ORDER BY COUNT(*) DESC) AS UserRank
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
),
RecentVotes AS (
    SELECT 
        PostId,
        COUNT(*) AS VoteCount,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    WHERE 
        CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        PostId
),
ClosedPosts AS (
    SELECT 
        PostId,
        CreationDate,
        (SELECT STRING_AGG(Name, ', ')
         FROM CloseReasonTypes crt 
         WHERE crt.Id = CAST(SUBSTRING(comment, 1, 2) AS smallint)) AS CloseReasons
    FROM 
        PostHistory 
    WHERE 
        PostHistoryTypeId = 10
        AND CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(rp.PostCount, 0) AS TotalPosts,
        COALESCE(rp.TotalScore, 0) AS TotalScore,
        COALESCE(rv.VoteCount, 0) AS RecentVoteCount,
        COALESCE(rv.UpVotes, 0) AS RecentUpVotes,
        COALESCE(rv.DownVotes, 0) AS RecentDownVotes,
        CASE 
            WHEN rp.UserRank <= 10 THEN 'Top Contributor' 
            ELSE 'Contributor' 
        END AS RankCategory
    FROM 
        Users u
    LEFT JOIN 
        RecursivePostCount rp ON u.Id = rp.OwnerUserId
    LEFT JOIN 
        RecentVotes rv ON EXISTS (SELECT 1 FROM Posts p WHERE p.Id = rv.PostId AND p.OwnerUserId = u.Id)
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalScore,
    tu.RecentVoteCount,
    tu.RecentUpVotes,
    tu.RecentDownVotes,
    tu.RankCategory,
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    cp.CloseReasons
FROM 
    TopUsers tu
JOIN 
    Posts p ON p.OwnerUserId = tu.UserId
LEFT JOIN 
    ClosedPosts cp ON p.Id = cp.PostId
WHERE 
    tu.TotalPosts > 0
ORDER BY 
    tu.TotalScore DESC, tu.RecentVoteCount DESC, p.CreationDate DESC;