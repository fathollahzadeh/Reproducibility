
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2) ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.OwnerDisplayName,
        rp.ViewCount,
        rp.Score,
        STRING_AGG(DISTINCT c.Text, ' | ') AS CommentTexts
    FROM 
        RankedPosts rp
        LEFT JOIN Comments c ON rp.PostId = c.PostId
    WHERE 
        rp.TagRank <= 3 
    GROUP BY 
        rp.PostId, rp.Title, rp.Tags, rp.OwnerDisplayName, rp.ViewCount, rp.Score
),
VotesData AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
FinalReport AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Tags,
        tp.OwnerDisplayName,
        tp.ViewCount,
        tp.Score,
        vd.UpVotes,
        vd.DownVotes,
        vd.TotalVotes,
        CASE 
            WHEN vd.TotalVotes > 0 THEN ROUND((vd.UpVotes * 1.0 / vd.TotalVotes) * 100, 2)
            ELSE 0
        END AS UpVotePercentage,
        tp.CommentTexts
    FROM 
        TopPosts tp
        LEFT JOIN VotesData vd ON tp.PostId = vd.PostId
)
SELECT 
    *
FROM 
    FinalReport
ORDER BY 
    Score DESC, ViewCount DESC;
