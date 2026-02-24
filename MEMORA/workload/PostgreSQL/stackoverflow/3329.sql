WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgScore,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
VotingData AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostsWithStatistics AS (
    SELECT 
        p.Id,
        p.Title,
        ps.PostCount,
        ps.TotalViews,
        ps.AvgScore,
        COALESCE(vd.UpVotes, 0) AS UpVotes,
        COALESCE(vd.DownVotes, 0) AS DownVotes,
        COALESCE(ur.Reputation, 0) AS UserReputation,
        ur.Rank AS UserRank,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        PostStatistics ps ON p.OwnerUserId = ps.OwnerUserId
    LEFT JOIN 
        VotingData vd ON p.Id = vd.PostId
    LEFT JOIN 
        UserReputation ur ON p.OwnerUserId = ur.UserId
)
SELECT 
    pws.Title,
    pws.PostCount,
    pws.TotalViews,
    pws.AvgScore,
    pws.UpVotes,
    pws.DownVotes,
    pws.UserReputation,
    pws.UserRank,
    pws.CreationDate,
    pws.PostRank
FROM 
    PostsWithStatistics pws
WHERE 
    pws.UserReputation > 1000
    AND pws.PostRank = 1
ORDER BY 
    pws.UserReputation DESC, 
    pws.TotalViews DESC;