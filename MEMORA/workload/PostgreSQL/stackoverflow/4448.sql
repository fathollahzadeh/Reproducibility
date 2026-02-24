
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        COUNT(DISTINCT p.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN vt.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN vt.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes vt ON p.Id = vt.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.Views
),

TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        Views,
        PostCount,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserStats
    WHERE 
        PostCount > 0
),

PostAnalysis AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS CloseCount,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END), 0) AS ReopenCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate
),

FilteredPosts AS (
    SELECT 
        pa.PostId,
        pa.Title,
        pa.Body,
        pa.CreationDate,
        pa.CommentCount,
        pa.CloseCount,
        pa.ReopenCount,
        RANK() OVER (ORDER BY pa.CommentCount DESC) AS CommentRank
    FROM 
        PostAnalysis pa
    WHERE 
        pa.CloseCount > 0
)

SELECT 
    tu.Rank,
    tu.DisplayName,
    tu.Reputation,
    fp.Title,
    fp.Body,
    fp.CreationDate,
    fp.CommentCount,
    fp.CloseCount,
    fp.ReopenCount
FROM 
    TopUsers tu
JOIN 
    FilteredPosts fp ON tu.UserId = (
        SELECT OwnerUserId 
        FROM Posts 
        WHERE Id = fp.PostId
    )
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.Rank, fp.CommentCount DESC;
