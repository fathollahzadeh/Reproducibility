WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerName,
        ARRAY_LENGTH(STRING_TO_ARRAY(p.Tags, '><'), 1) AS TagCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
PostWithVotes AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.OwnerName,
        rp.TagCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 1 THEN 1 ELSE 0 END), 0) AS AcceptedByOriginatorVotes,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.CreationDate, rp.OwnerUserId, rp.OwnerName, rp.TagCount
),
TopPosts AS (
    SELECT 
        pw.*,
        ROW_NUMBER() OVER (ORDER BY UpVotes DESC, CreationDate DESC) AS OverallRank
    FROM 
        PostWithVotes pw
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.OwnerName,
    tp.TagCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.AcceptedByOriginatorVotes,
    tp.CommentCount
FROM 
    TopPosts tp
WHERE 
    tp.OverallRank <= 10 
ORDER BY 
    tp.UpVotes DESC, 
    tp.CreationDate DESC;