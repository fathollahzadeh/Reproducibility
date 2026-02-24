WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id
),
HighReputationUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        TotalBounty,
        TotalUpVotes,
        TotalDownVotes
    FROM UserReputation
    WHERE Reputation > 1000
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(pc.CommentCount, 0) AS Comments,
        COALESCE(ah.AcceptedAnswerId, 0) AS AcceptedAnswerId
    FROM Posts p
    INNER JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (SELECT 
                    PostId, 
                    COUNT(*) AS CommentCount 
                FROM Comments 
                GROUP BY PostId) pc ON p.Id = pc.PostId
    LEFT JOIN (SELECT 
                    ParentId, 
                    AcceptedAnswerId 
                FROM Posts 
                WHERE PostTypeId = 1) ah ON p.Id = ah.ParentId
),
PostsWithUserDetails AS (
    SELECT 
        pd.*,
        ur.Reputation,
        ur.TotalUpVotes,
        ur.TotalDownVotes
    FROM PostDetails pd
    JOIN HighReputationUsers ur ON pd.OwnerDisplayName = ur.DisplayName
)
SELECT 
    PostId,
    Title,
    PostCreationDate,
    OwnerDisplayName,
    Reputation,
    Comments,
    TotalUpVotes,
    TotalDownVotes,
    CASE 
        WHEN AcceptedAnswerId IS NOT NULL THEN 'Yes' 
        ELSE 'No' 
    END AS HasAcceptedAnswer
FROM PostsWithUserDetails
ORDER BY PostCreationDate DESC
LIMIT 50;
