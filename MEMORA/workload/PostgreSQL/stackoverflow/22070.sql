WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(UPPER(p.Tags), 'No Tags') AS NormalizedTags,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVotesCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVotesCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
RecentPostStats AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.Score,
        pd.ViewCount,
        pd.NormalizedTags,
        pd.OwnerDisplayName,
        pd.UpVotesCount,
        pd.DownVotesCount,
        ROW_NUMBER() OVER (PARTITION BY pd.OwnerDisplayName ORDER BY pd.CreationDate DESC) AS rn,
        SUM(pd.Score) OVER (PARTITION BY pd.OwnerDisplayName) AS TotalScorePerUser
    FROM 
        PostDetails pd
),
UserBenchmark AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN r.rn = 1 THEN 1 ELSE 0 END), 0) AS RecentPostCount,
        SUM(r.UpVotesCount) - SUM(r.DownVotesCount) AS NetVotes
    FROM 
        Users u
    LEFT JOIN 
        RecentPostStats r ON u.Id = (SELECT OwnerUserId FROM Posts p WHERE p.Id = r.PostId LIMIT 1)
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    ub.UserId,
    ub.DisplayName,
    ub.Reputation,
    ub.RecentPostCount,
    ub.NetVotes,
    CONCAT('User ', ub.DisplayName, ' has ', ub.RecentPostCount, ' recent posts with a net vote score of ', ub.NetVotes) AS UserSummary,
    (
        SELECT STRING_AGG(DISTINCT CAST(pd.NormalizedTags AS VARCHAR), ', ')
        FROM RecentPostStats pd
        WHERE pd.PostId IN (SELECT PostId FROM RecentPostStats rs WHERE rs.OwnerDisplayName = ub.DisplayName)
    ) AS TagsSummary
FROM 
    UserBenchmark ub
WHERE 
    ub.Reputation > 1000
ORDER BY 
    ub.RecentPostCount DESC, ub.NetVotes DESC
LIMIT 5;