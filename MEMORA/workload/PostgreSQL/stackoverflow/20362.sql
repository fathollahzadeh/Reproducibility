
WITH UserReputation AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY u.CreationDate DESC) AS rn,
        CASE 
            WHEN u.Reputation IS NULL THEN 'No Reputation'
            WHEN u.Reputation < 1000 THEN 'Novice'
            WHEN u.Reputation < 5000 THEN 'Intermediate'
            ELSE 'Expert'
        END AS ReputationLevel
    FROM Users u
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        MAX(p.CreationDate) AS LatestCreationDate,
        p.OwnerUserId,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 
            ELSE 0 
        END AS IsAccepted
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.OwnerUserId, p.AcceptedAnswerId
),
UserPosts AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        ps.PostId,
        ps.Title,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        ps.TotalBounty,
        ps.LatestCreationDate,
        ps.IsAccepted,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY ps.TotalBounty DESC, ps.CommentCount DESC) AS PostRank
    FROM UserReputation u
    JOIN PostStats ps ON u.Id = ps.OwnerUserId
)

SELECT 
    ur.DisplayName,
    ur.Reputation,
    ur.ReputationLevel,
    COUNT(ps.PostId) AS TotalPosts,
    SUM(CASE WHEN ps.IsAccepted = 1 THEN 1 ELSE 0 END) AS AcceptedPosts,
    SUM(ps.TotalBounty) AS TotalBounties,
    AVG(ps.UpVotes - ps.DownVotes) AS AverageVoteDifferential,
    STRING_AGG(ps.Title, '; ') AS PostTitles
FROM UserPosts ps
JOIN UserReputation ur ON ps.UserId = ur.Id
WHERE ur.Reputation > 0
GROUP BY ur.DisplayName, ur.Reputation, ur.ReputationLevel
HAVING COUNT(ps.PostId) > 5
ORDER BY TotalPosts DESC, TotalBounties DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
