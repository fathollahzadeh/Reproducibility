WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.UpVotes) AS TotalUpVotes,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(u.UpVotes) > 100
),
ClosedPostDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        ph.Text
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        pht.Name ILIKE 'Post Closed'
    AND 
        ph.CreationDate > cast('2024-10-01' as date) - INTERVAL '6 months'
),
PostAnswers AS (
    SELECT 
        p.Id AS PostId,
        COUNT(a.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id
)
SELECT 
    tp.UserId,
    tp.DisplayName,
    COUNT(DISTINCT rp.PostId) AS NumberOfPosts,
    SUM(pa.AnswerCount) AS TotalAnswers,
    COALESCE(SUM(CASE WHEN cpd.PostId IS NOT NULL THEN 1 ELSE 0 END), 0) AS ClosedPostCount,
    STRING_AGG(DISTINCT rp.Title, ', ') AS TopPostTitles
FROM 
    TopUsers tp
LEFT JOIN 
    RankedPosts rp ON tp.UserId = rp.OwnerUserId AND rp.Rank <= 5
LEFT JOIN 
    PostAnswers pa ON rp.PostId = pa.PostId
LEFT JOIN 
    ClosedPostDetails cpd ON rp.PostId = cpd.PostId
GROUP BY 
    tp.UserId, tp.DisplayName
ORDER BY 
    TotalAnswers DESC, NumberOfPosts DESC;