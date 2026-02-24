
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS UpVotePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS DownVotePosts,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        AVG(EXTRACT(EPOCH FROM COALESCE(p.LastActivityDate, p.CreationDate) - p.CreationDate)) AS AvgPostActiveTime
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        UpVotePosts,
        DownVotePosts,
        AcceptedAnswers,
        AvgPostActiveTime,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserStats
),
PostVoteSummary AS (
    SELECT 
        p.OwnerUserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    u.PostCount,
    u.UpVotePosts,
    u.DownVotePosts,
    u.AcceptedAnswers,
    u.AvgPostActiveTime,
    pvs.TotalVotes,
    pvs.UpVotes,
    pvs.DownVotes,
    u.ReputationRank
FROM 
    TopUsers u
JOIN 
    PostVoteSummary pvs ON u.UserId = pvs.OwnerUserId
WHERE 
    u.ReputationRank <= 10
ORDER BY 
    u.Reputation DESC, pvs.TotalVotes DESC;
