WITH UserRankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0
),
TopUserPosts AS (
    SELECT 
        urp.PostId,
        urp.Title,
        urp.Score,
        urp.UserDisplayName
    FROM 
        UserRankedPosts urp
    WHERE 
        urp.PostRank <= 5
),
PostComments AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
)
SELECT 
    tup.PostId,
    tup.Title,
    tup.Score,
    tup.UserDisplayName,
    pc.CommentCount
FROM 
    TopUserPosts tup
JOIN 
    PostComments pc ON tup.PostId = pc.PostId
ORDER BY 
    tup.Score DESC, pc.CommentCount DESC;