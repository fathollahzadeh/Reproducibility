WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11, 12, 13) 
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
        MAX(p.CreationDate) AS LastPostDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.Reputation
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
    HAVING COUNT(p.Id) > 10 
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(UPVOTES.UpCount, 0) AS UpVoteCount,
        COALESCE(DOWNVOTES.DownCount, 0) AS DownVoteCount,
        COALESCE(CLOSEHIST.CloseCount, 0) AS CloseCount,
        COALESCE(REOPENHIST.ReopenCount, 0) AS ReopenCount,
        p.CreationDate,
        DENSE_RANK() OVER (ORDER BY COALESCE(UPVOTES.UpCount, 0) - COALESCE(DOWNVOTES.DownCount, 0) DESC) AS Rank
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS UpCount
        FROM Votes
        WHERE VoteTypeId = 2
        GROUP BY PostId
    ) AS UPVOTES ON p.Id = UPVOTES.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS DownCount
        FROM Votes
        WHERE VoteTypeId = 3
        GROUP BY PostId
    ) AS DOWNVOTES ON p.Id = DOWNVOTES.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CloseCount
        FROM RecursivePostHistory
        WHERE PostHistoryTypeId = 10
        GROUP BY PostId
    ) AS CLOSEHIST ON p.Id = CLOSEHIST.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS ReopenCount
        FROM RecursivePostHistory
        WHERE PostHistoryTypeId = 11
        GROUP BY PostId
    ) AS REOPENHIST ON p.Id = REOPENHIST.PostId
    WHERE p.CreationDate > (cast('2024-10-01' as date) - INTERVAL '1 year') 
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.UpVoteCount,
    ps.DownVoteCount,
    ps.CloseCount,
    ps.ReopenCount,
    pht.Name AS PostHistoryType,
    u.DisplayName AS LastEditor,
    ur.Reputation AS EditorReputation,
    tt.TagName AS PopularTag
FROM PostStats ps
LEFT JOIN RecursivePostHistory rph ON ps.PostId = rph.PostId AND rph.rn = 1 
LEFT JOIN PostHistoryTypes pht ON rph.PostHistoryTypeId = pht.Id
LEFT JOIN Users u ON rph.UserId = u.Id
LEFT JOIN UserReputation ur ON u.Id = ur.UserId
LEFT JOIN TopTags tt ON tt.PostCount > 0 
WHERE
    (ps.UpVoteCount - ps.DownVoteCount) > 5 
ORDER BY ps.Rank;