
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COALESCE(vote.UpVotes, 0) AS UpVotes,
        COALESCE(vote.DownVotes, 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT UserId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
                          SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
         FROM Votes 
         GROUP BY UserId) vote ON u.Id = vote.UserId
    WHERE 
        p.PostTypeId = 1 AND
        p.LastActivityDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, vote.UpVotes, vote.DownVotes, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp 
    WHERE 
        Rank <= 5
)
SELECT 
    up.DisplayName AS UserName,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes
FROM 
    TopPosts tp
JOIN 
    Users up ON tp.OwnerUserId = up.Id
ORDER BY 
    tp.Score DESC, 
    tp.CreationDate DESC;
