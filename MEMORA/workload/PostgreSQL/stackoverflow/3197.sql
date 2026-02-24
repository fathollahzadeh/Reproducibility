
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(p.Id) > 5
),
CommentedPosts AS (
    SELECT 
        c.PostId, 
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.LastActivityDate,
        COALESCE(cp.CommentCount, 0) AS CommentCount,
        pu.DisplayName AS PopularUser
    FROM 
        RankedPosts rp
    LEFT JOIN 
        CommentedPosts cp ON rp.PostId = cp.PostId
    JOIN 
        Posts u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId LIMIT 1)
    JOIN 
        PopularUsers pu ON pu.UserId = u.Id
    WHERE 
        rp.RN = 1
),
PostHistoryAggregate AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS HistoryCount,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        p.Id
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.CreationDate,
    tp.LastActivityDate,
    tp.CommentCount,
    tp.PopularUser,
    pha.HistoryCount,
    pha.HistoryTypes
FROM 
    TopPosts tp
JOIN 
    PostHistoryAggregate pha ON tp.PostId = pha.PostId
ORDER BY 
    tp.Score DESC, 
    tp.LastActivityDate DESC;
