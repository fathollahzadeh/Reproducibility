
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        p.Score, 
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts AS p
    JOIN 
        Users AS u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes AS v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.ViewCount, 
        rp.Score, 
        rp.OwnerDisplayName,
        rp.VoteCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts AS rp
    WHERE 
        rp.RN <= 3 AND 
        rp.Score > 10 
    ORDER BY 
        rp.Score DESC, rp.ViewCount DESC
)

SELECT 
    f.PostId, 
    f.Title, 
    f.CreationDate, 
    f.ViewCount, 
    f.Score, 
    f.OwnerDisplayName, 
    f.VoteCount, 
    f.UpVotes, 
    f.DownVotes,
    COALESCE(ph.Comment, 'No comments') AS LastEditComment
FROM 
    FilteredPosts AS f
LEFT JOIN 
    PostHistory AS ph ON f.PostId = ph.PostId 
    AND ph.CreationDate = (
        SELECT MAX(ph2.CreationDate) 
        FROM PostHistory AS ph2 
        WHERE ph2.PostId = f.PostId
    )
WHERE 
    f.ViewCount > 100
ORDER BY 
    f.ViewCount DESC;
