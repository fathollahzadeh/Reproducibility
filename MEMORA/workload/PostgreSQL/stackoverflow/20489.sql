WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostsVotedOn
    FROM 
        Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    LEFT JOIN Posts p ON p.Id = v.PostId
    WHERE 
        u.Reputation > 100 
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalVotes,
        UpVotes,
        DownVotes,
        PostsVotedOn,
        RANK() OVER (ORDER BY TotalVotes DESC) AS VoteRank
    FROM 
        UserVoteStats
),
PostActiveStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount, 
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenCount,
        MAX(p.LastActivityDate) AS LastActivity,
        p.AcceptedAnswerId IS NULL AS IsUnanswered
    FROM 
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.AcceptedAnswerId
),
UserPostInteraction AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(CASE WHEN up.PostId IS NOT NULL THEN 1 ELSE 0 END) AS PostsInteracted
    FROM 
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN PostActiveStats up ON up.PostId = p.Id 
    GROUP BY 
        u.Id
    HAVING 
        COUNT(DISTINCT p.Id) > 0 
)
SELECT 
    tu.DisplayName,
    tu.TotalVotes,
    tu.UpVotes,
    tu.DownVotes,
    tu.PostsVotedOn,
    pas.CommentCount,
    pas.CloseCount,
    pas.ReopenCount,
    upi.PostsCreated,
    upi.PostsInteracted,
    pas.LastActivity,
    pas.IsUnanswered
FROM 
    TopUsers tu
JOIN 
    PostActiveStats pas ON pas.CommentCount > 5 
JOIN 
    UserPostInteraction upi ON upi.UserId = tu.UserId
WHERE 
    tu.VoteRank <= 10 
ORDER BY 
    tu.TotalVotes DESC, 
    pas.LastActivity DESC;