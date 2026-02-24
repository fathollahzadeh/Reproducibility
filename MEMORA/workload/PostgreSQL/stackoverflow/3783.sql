WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(c.Id) DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.*,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName,
        (UpVoteCount - DownVoteCount) AS NetVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rn <= 3
),
FinalResults AS (
    SELECT 
        tp.PostID,
        tp.Title,
        tp.CreationDate,
        tp.OwnerDisplayName,
        tp.CommentCount,
        tp.NetVotes,
        CASE 
            WHEN tp.NetVotes >= 10 THEN 'High Engagement'
            WHEN tp.NetVotes BETWEEN 1 AND 9 THEN 'Moderate Engagement'
            ELSE 'Low Engagement' 
        END AS EngagementLevel
    FROM 
        TopPosts tp
)
SELECT 
    f.*,
    COALESCE(lt.Name, 'No Link') AS LinkDescription
FROM 
    FinalResults f
LEFT JOIN 
    PostLinks pl ON f.PostID = pl.PostId
LEFT JOIN 
    LinkTypes lt ON pl.LinkTypeId = lt.Id
ORDER BY 
    f.NetVotes DESC NULLS LAST;