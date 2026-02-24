
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title, 
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END), 0) AS NetVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END), 0) DESC) AS VoteRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.NetVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.VoteRank <= 5 
),
PostWithBadges AS (
    SELECT 
        tp.*, 
        COUNT(b.Id) AS BadgeCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        Badges b ON tp.PostId = b.UserId
    GROUP BY 
        tp.PostId, tp.Title, tp.Body, tp.Tags, tp.CreationDate, tp.OwnerDisplayName, tp.NetVotes
)
SELECT 
    pwb.PostId,
    pwb.Title,
    pwb.Body,
    pwb.Tags,
    pwb.CreationDate,
    pwb.OwnerDisplayName,
    pwb.NetVotes,
    pwb.BadgeCount
FROM 
    PostWithBadges pwb
ORDER BY 
    pwb.NetVotes DESC, pwb.CreationDate DESC;
