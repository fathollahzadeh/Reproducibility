
WITH RECURSIVE UserPostScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        COALESCE(COUNT(p.Id), 0) AS PostCount
    FROM 
        Users u 
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalScore,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        UserPostScores
    WHERE 
        PostCount > 0
),
TagPostCounts AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    GROUP BY 
        t.TagName
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId = 6 THEN 1 END) AS CloseVotes,
        COUNT(CASE WHEN v.VoteTypeId = 7 THEN 1 END) AS ReopenVotes
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        v.PostId
)
SELECT 
    tu.DisplayName,
    tu.TotalScore,
    tc.TagName,
    tc.PostCount AS TotalPostsByTag,
    COALESCE(rv.UpVotes, 0) AS RecentUpVotes,
    COALESCE(rv.DownVotes, 0) AS RecentDownVotes,
    COALESCE(rv.CloseVotes, 0) AS RecentCloseVotes,
    COALESCE(rv.ReopenVotes, 0) AS RecentReopenVotes
FROM 
    TopUsers tu
JOIN 
    TagPostCounts tc ON tc.PostCount > 0
LEFT JOIN 
    RecentVotes rv ON rv.PostId IN (
        SELECT p.Id 
        FROM Posts p 
        WHERE p.OwnerUserId = tu.UserId
    )
WHERE 
    tu.Rank <= 10 
    AND (rv.UpVotes IS NOT NULL OR rv.DownVotes IS NOT NULL)
ORDER BY 
    tu.TotalScore DESC, 
    tc.PostCount DESC;
