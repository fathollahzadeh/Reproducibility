
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Body,
        p.Tags, 
        p.CreationDate, 
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankOrder
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName
), FilteredPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Body, 
        rp.Tags, 
        rp.CreationDate, 
        rp.OwnerDisplayName, 
        rp.CommentCount, 
        rp.UpVotes, 
        rp.DownVotes,
        rp.RankOrder
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankOrder <= 5 
)

SELECT 
    fp.PostId, 
    fp.Title, 
    fp.Body, 
    fp.Tags,
    fp.CreationDate, 
    fp.OwnerDisplayName, 
    fp.CommentCount,
    fp.UpVotes, 
    fp.DownVotes,
    COALESCE(pt.Name, 'No Post Type') AS PostTypeName,
    COALESCE(b.Name, 'No Badge') AS UserBadgeName
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostTypes pt ON fp.PostId = pt.Id
LEFT JOIN 
    Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = fp.PostId) AND b.Date >= fp.CreationDate
ORDER BY 
    fp.CreationDate DESC;
