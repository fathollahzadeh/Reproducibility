WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RevisionNumber
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) 
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.Reputation) AS TotalReputation,
        COUNT(b.Id) AS BadgeCount,
        COUNT(DISTINCT ph.PostId) AS ClosedPosts
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        RecursivePostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostVoteStats AS (
    SELECT
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        AVG(CASE WHEN VoteTypeId IN (2, 3) THEN VoteTypeId END) AS AvgVoteType
    FROM 
        Votes
    GROUP BY 
        PostId
),
CombinedStats AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        u.TotalReputation,
        u.BadgeCount,
        u.ClosedPosts,
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        COALESCE(v.TotalUpVotes, 0) AS PostUpVotes,
        COALESCE(v.TotalDownVotes, 0) AS PostDownVotes,
        COALESCE(v.AvgVoteType, 0) AS PostAvgVote
    FROM 
        UserReputation u
    JOIN 
        Posts p ON u.UserId = p.OwnerUserId
    LEFT JOIN 
        PostVoteStats v ON p.Id = v.PostId
    ORDER BY 
        u.TotalReputation DESC, p.CreationDate DESC
)
SELECT 
    cs.DisplayName AS UserDisplayName,
    cs.TotalReputation,
    cs.BadgeCount,
    cs.ClosedPosts,
    cs.Title AS PostTitle,
    cs.PostCreationDate,
    cs.PostUpVotes,
    cs.PostDownVotes,
    cs.PostAvgVote
FROM 
    CombinedStats cs
WHERE 
    cs.ClosedPosts > 0
ORDER BY 
    cs.TotalReputation DESC, cs.PostCreationDate DESC
LIMIT 100;