
WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        U.DisplayName AS OwnerDisplayName,
        EXTRACT(EPOCH FROM (TIMESTAMP '2024-10-01 12:34:56' - p.CreationDate)) / 3600 AS AgeInHours,
        COUNT(t.TagName) AS TagCount,
        CASE 
            WHEN p.Score > 10 THEN 'Highly Rated'
            WHEN p.Score BETWEEN 1 AND 10 THEN 'Moderately Rated'
            ELSE 'Low Rated'
        END AS RatingCategory
    FROM Posts p
    JOIN Users U ON p.OwnerUserId = U.Id
    LEFT JOIN LATERAL (
        SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '>')) AS TagName
    ) AS t ON TRUE
    WHERE p.PostTypeId = 1  
    GROUP BY p.Id, p.Title, p.ViewCount, p.Score, p.AnswerCount, p.CommentCount, U.DisplayName
),
PopularPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        Score,
        AnswerCount,
        RatingCategory,
        DENSE_RANK() OVER (PARTITION BY RatingCategory ORDER BY ViewCount DESC) AS Rank
    FROM PostStatistics
),
TopPopularPosts AS (
    SELECT PostId, Title, ViewCount, Score, AnswerCount, RatingCategory
    FROM PopularPosts
    WHERE Rank <= 5
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS EditDate,
        ph.UserDisplayName,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS EditRank
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 6)  
)
SELECT 
    tp.Title,
    tp.ViewCount,
    tp.Score,
    tp.AnswerCount,
    rp.EditDate AS LastEditDate,
    rp.UserDisplayName AS LastEditedBy,
    tp.RatingCategory
FROM TopPopularPosts tp
LEFT JOIN ( 
    SELECT PostId, EditDate, UserDisplayName
    FROM RecentEdits
    WHERE EditRank = 1
) rp ON tp.PostId = rp.PostId
ORDER BY tp.RatingCategory, tp.ViewCount DESC;
