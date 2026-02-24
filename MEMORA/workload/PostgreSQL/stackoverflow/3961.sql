
WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        U.DisplayName AS OwnerDisplayName, 
        COUNT(c.Id) AS CommentCount, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, U.DisplayName, p.OwnerUserId
), 

FilteredPosts AS (
    SELECT 
        rp.Id, 
        rp.Title, 
        rp.CreationDate, 
        rp.OwnerDisplayName, 
        rp.CommentCount, 
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)

SELECT 
    f.Title, 
    f.OwnerDisplayName, 
    f.CreationDate,
    COALESCE(f.UpVotes - f.DownVotes, 0) AS NetScore,
    CONCAT('Comments: ', f.CommentCount) AS CommentInfo,
    CASE 
        WHEN f.CommentCount = 0 THEN 'No Comments Yet'
        ELSE 'Has Comments'
    END AS CommentStatus
FROM 
    FilteredPosts f
RIGHT JOIN 
    Users u ON f.OwnerDisplayName = u.DisplayName
WHERE 
    u.Reputation > 1000
ORDER BY 
    NetScore DESC, 
    f.CreationDate DESC;
