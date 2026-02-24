WITH UserReputation AS (
    SELECT 
        Users.Id AS UserId,
        Users.Reputation,
        COUNT(DISTINCT Posts.Id) AS TotalPosts,
        SUM(CASE WHEN Posts.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        SUM(CASE WHEN Posts.Score < 0 THEN 1 ELSE 0 END) AS NegativeScorePosts
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY 
        Users.Id, Users.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        TotalPosts,
        PositiveScorePosts,
        NegativeScorePosts,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserReputation
),
PostVoteSummary AS (
    SELECT 
        Posts.Id AS PostId,
        COUNT(CASE WHEN Votes.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN Votes.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN Votes.VoteTypeId IN (6, 10) THEN 1 END) AS CloseVotes,
        COUNT(CASE WHEN Votes.VoteTypeId IN (7, 11) THEN 1 END) AS ReopenVotes
    FROM 
        Posts
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Posts.Id
),
PostHistoryAudit AS (
    SELECT 
        PostId,
        COUNT(*) AS RevisionCount,
        STRING_AGG(DISTINCT CASE WHEN PostHistoryTypeId = 10 THEN CloseReasonType.Name END, ', ') AS CloseReasons
    FROM 
        PostHistory
    LEFT JOIN 
        CloseReasonTypes CloseReasonType ON PostHistory.Comment = CAST(CloseReasonType.Id AS VARCHAR)
    GROUP BY 
        PostId
),
CombinedStats AS (
    SELECT
        p.Id AS PostId,
        u.DisplayName AS UserDisplayName,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(vs.UpVotes, 0) AS UpVotes,
        COALESCE(vs.DownVotes, 0) AS DownVotes,
        COALESCE(ph.RevisionCount, 0) AS RevisionCount,
        COALESCE(ph.CloseReasons, 'None') AS CloseReasons,
        u.Reputation AS UserReputation,
        tu.ReputationRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostVoteSummary vs ON p.Id = vs.PostId
    LEFT JOIN 
        PostHistoryAudit ph ON p.Id = ph.PostId
    JOIN 
        TopUsers tu ON u.Id = tu.UserId
    WHERE 
        (p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year')
        AND (u.Reputation BETWEEN 100 AND 10000 OR u.Location IS NOT NULL)
)
SELECT 
    *,
    CASE 
        WHEN UserReputation > 5000 THEN 'Elite Contributor'
        WHEN UserReputation > 1000 THEN 'Frequent Contributor'
        ELSE 'New Contributor'
    END AS ContributorType
FROM 
    CombinedStats
ORDER BY 
    ReputationRank, UpVotes DESC
LIMIT 100;