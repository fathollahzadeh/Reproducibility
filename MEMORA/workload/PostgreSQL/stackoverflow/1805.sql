
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2020-01-01'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        (rp.UpVotes - rp.DownVotes) AS VoteScore
    FROM 
        RankedPosts rp
    WHERE 
        rp.CommentCount > 5 AND (rp.UpVotes - rp.DownVotes) > 0
)
SELECT 
    f.Title,
    f.CreationDate,
    f.CommentCount,
    f.UpVotes,
    f.DownVotes,
    CASE 
        WHEN f.CommentCount > 10 THEN 'Highly Engaged'
        WHEN f.CommentCount BETWEEN 6 AND 10 THEN 'Moderately Engaged'
        ELSE 'Low Engagement'
    END AS EngagementLevel,
    pt.Name AS PostType
FROM 
    FilteredPosts f
LEFT JOIN 
    PostTypes pt ON pt.Id = (SELECT PostTypeId FROM Posts WHERE Id = f.PostId LIMIT 1)
ORDER BY 
    f.CreationDate DESC
LIMIT 50;
