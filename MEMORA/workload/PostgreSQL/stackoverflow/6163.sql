
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON v.UserId = u.Id AND v.PostId = p.Id
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        (UpVotes - DownVotes) AS NetVotes,
        PostCount + (CommentCount / 2) AS EngagementScore 
    FROM UserReputation
    WHERE PostCount > 0
    ORDER BY NetVotes DESC, EngagementScore DESC
    LIMIT 10
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        p.OwnerUserId
    FROM Posts p
    JOIN TopUsers tu ON p.OwnerUserId = tu.UserId
),
FinalOutput AS (
    SELECT 
        tu.DisplayName,
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.Score,
        RANK() OVER (ORDER BY pd.Score DESC) AS PostRank
    FROM PostDetails pd
    JOIN TopUsers tu ON pd.OwnerUserId = tu.UserId
)
SELECT 
    DisplayName,
    PostId,
    Title,
    CreationDate,
    Score,
    PostRank
FROM FinalOutput
ORDER BY DisplayName, PostRank;
