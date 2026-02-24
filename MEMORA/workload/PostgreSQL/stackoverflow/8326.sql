
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01 00:00:00'
        AND p.PostTypeId IN (1, 2)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.PostTypeId
),
AggregatedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.UpVotes > rp.DownVotes THEN 'Positive'
            WHEN rp.DownVotes > rp.UpVotes THEN 'Negative'
            ELSE 'Neutral'
        END AS VoteSentiment
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 10
)
SELECT 
    ad.PostId,
    ad.Title,
    ad.OwnerDisplayName,
    ad.CommentCount,
    ad.UpVotes,
    ad.DownVotes,
    ad.VoteSentiment,
    pt.Name AS PostTypeName,
    COALESCE(cf.Count, 0) AS TagUsageCount
FROM 
    AggregatedData ad
JOIN 
    PostTypes pt ON ad.PostId = pt.Id
LEFT JOIN 
    (SELECT 
        p.Id AS PostId, 
        COUNT(t.Id) AS Count
     FROM 
        Posts p
     JOIN 
        Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
     GROUP BY 
        p.Id) cf ON ad.PostId = cf.PostId
ORDER BY 
    ad.CommentCount DESC, ad.UpVotes DESC;
