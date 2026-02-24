
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.Body,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, p.Score, p.Body, u.DisplayName
),
TopTaggedPosts AS (
    SELECT 
        rp.*,
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC, rp.CreationDate ASC) AS OverallRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 3 
)
SELECT 
    ttp.PostId,
    ttp.Title,
    ttp.Tags,
    ttp.CreationDate,
    ttp.Score,
    ttp.Body,
    ttp.OwnerName,
    ttp.CommentCount,
    ttp.UpVotes,
    ttp.DownVotes
FROM 
    TopTaggedPosts ttp
WHERE 
    ttp.OverallRank <= 10 
ORDER BY 
    ttp.Score DESC, ttp.CreationDate ASC;
