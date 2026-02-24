
WITH UserScore AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        (u.UpVotes - u.DownVotes) AS NetVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        NetVotes,
        PostCount,
        PositivePosts,
        NegativePosts,
        RANK() OVER (ORDER BY Reputation DESC) AS RankByReputation,
        RANK() OVER (ORDER BY NetVotes DESC) AS RankByVotes
    FROM UserScore
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS AuthorName,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        p.OwnerUserId
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(Id) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    WHERE p.CreationDate >= timestamp '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId, 
        ph.PostHistoryTypeId, 
        p.Title AS PostTitle, 
        ph.CreationDate AS ModificationDate,
        COALESCE(ph.Comment, 'No comments') AS ModificationComment
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.CreationDate >= timestamp '2024-10-01 12:34:56' - INTERVAL '6 months'
),
CombinedData AS (
    SELECT 
        pu.UserId,
        pu.DisplayName,
        pd.PostId,
        pd.Title,
        ph.ModificationComment,
        ROW_NUMBER() OVER (PARTITION BY pu.UserId ORDER BY pd.CreationDate DESC) AS PostRank
    FROM TopUsers pu
    JOIN PostDetails pd ON pu.UserId = pd.OwnerUserId
    LEFT JOIN PostHistoryDetails ph ON pd.PostId = ph.PostId
)
SELECT 
    t.UserId,
    t.DisplayName,
    p.Title AS PostTitle,
    t.ModificationComment,
    t.PostRank,
    CASE 
        WHEN t.PostRank = 1 THEN 'Most Recent Post'
        ELSE 'Earlier Post'
    END AS PostStatus
FROM CombinedData t
LEFT JOIN PostDetails p ON t.PostId = p.PostId
WHERE t.PostRank <= 5
ORDER BY t.UserId, t.PostRank;
