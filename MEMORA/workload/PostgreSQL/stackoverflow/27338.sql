
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS Author,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        LATERAL (
            SELECT 
                unnest(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS TagName
        ) t ON TRUE
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, u.DisplayName, p.CreationDate, p.ViewCount, p.Score
),
QuestionStats AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.ViewCount,
        r.Score,
        r.Author,
        r.Tags,
        COALESCE(SUM(c.Score), 0) AS TotalCommentScore,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        RankedPosts r
    LEFT JOIN 
        Comments c ON r.PostId = c.PostId
    LEFT JOIN 
        Votes v ON r.PostId = v.PostId
    WHERE 
        r.PostRank = 1  
    GROUP BY 
        r.PostId, r.Title, r.CreationDate, r.ViewCount, r.Score, r.Author, r.Tags
),
FinalResults AS (
    SELECT 
        qs.PostId,
        qs.Title,
        qs.CreationDate,
        qs.ViewCount,
        qs.Score,
        qs.Author,
        qs.Tags,
        qs.TotalCommentScore,
        qs.UpVotes,
        qs.DownVotes,
        (qs.UpVotes - qs.DownVotes) AS VoteDifference
    FROM 
        QuestionStats qs
)
SELECT 
    * 
FROM 
    FinalResults
WHERE 
    VoteDifference > 0  
ORDER BY 
    VoteDifference DESC, 
    ViewCount DESC;
