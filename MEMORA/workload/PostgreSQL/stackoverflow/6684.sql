
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        u.DisplayName AS OwnerDisplayName, 
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, u.DisplayName
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1 AND rp.ViewCount > 1000 
),
FinalResults AS (
    SELECT 
        pp.*,
        (pp.UpVotes - pp.DownVotes) AS NetVotes,
        CASE 
            WHEN pp.ViewCount > 5000 THEN 'Highly Viewed' 
            WHEN pp.ViewCount > 1000 THEN 'Moderately Viewed' 
            ELSE 'Low Visibility' 
        END AS ViewCategory
    FROM 
        PopularPosts pp
)
SELECT 
    FR.PostId,
    FR.Title,
    FR.OwnerDisplayName,
    FR.CreationDate,
    FR.ViewCount,
    FR.CommentCount,
    FR.UpVotes,
    FR.DownVotes,
    FR.NetVotes,
    FR.ViewCategory
FROM 
    FinalResults FR
ORDER BY 
    FR.NetVotes DESC, 
    FR.ViewCount DESC;
