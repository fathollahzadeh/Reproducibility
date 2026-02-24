
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.Score > 0
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 5
),
RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    WHERE 
        c.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
    GROUP BY 
        c.PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        p.Title AS PostTitle,
        p.OwnerUserId,
        ph.Comment || COALESCE(NULLIF(ph.Text, ''), 'No changes made') AS EditDetails,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS history_rn
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 12) 
)
SELECT 
    u.DisplayName,
    r.Title AS PostTitle,
    u.TotalScore,
    u.PostCount,
    r.PostId,
    r.Title AS RankedPostTitle,
    r.Score AS RankedPostScore,
    COALESCE(c.CommentCount, 0) AS RecentCommentCount,
    ph.EditDetails
FROM 
    TopUsers u
JOIN 
    RankedPosts r ON u.UserId = r.OwnerUserId
LEFT JOIN 
    RecentComments c ON r.PostId = c.PostId
LEFT JOIN 
    PostHistoryDetails ph ON r.PostId = ph.PostId AND ph.history_rn = 1
WHERE 
    r.rn = 1
ORDER BY 
    u.TotalScore DESC, r.Score DESC, u.DisplayName;
