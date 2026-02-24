WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS UserRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostVoteCounts AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
Combined AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        COALESCE(pvc.UpVotes, 0) AS UpVotes,
        COALESCE(pvc.DownVotes, 0) AS DownVotes,
        rp.UserRank,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVoteCounts pvc ON rp.PostId = pvc.PostId
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.ViewCount, pvc.UpVotes, pvc.DownVotes, rp.UserRank
)
SELECT 
    c.PostId,
    c.Title,
    c.ViewCount,
    c.UpVotes,
    c.DownVotes,
    c.CommentCount,
    CASE 
        WHEN c.UserRank <= 5 THEN 'Top Posts for User'
        ELSE 'Other Posts'
    END AS PostCategory
FROM 
    Combined c
ORDER BY 
    c.UpVotes DESC, c.ViewCount DESC
LIMIT 10;